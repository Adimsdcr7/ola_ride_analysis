CREATE DATABASE Ola;

USE ola;

# Booking funnel Analysis

-- Q1) Total number of booking?

SELECT COUNT(*) AS total_bookings
FROM bookings;

-- Q2) How many bookings succeed vs fail?

SELECT
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) AS successful,
    SUM(CASE WHEN booking_status != 'Success' THEN 1 ELSE 0 END) AS failed
FROM bookings;

-- Q3) What % of bookings actually succeed?

SELECT
ROUND(AVG(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) * 100, 2) AS success_rate
FROM bookings;


-- Q4) Who cancels more — customer or driver?

SELECT booking_status, COUNT(*) AS total
FROM bookings
WHERE booking_status != 'Success'
GROUP BY booking_status;

# REVENUE LEAKAGE

-- Q5) Total revenue generated

SELECT ROUND(SUM(booking_value), 2) AS total_revenue
FROM bookings
WHERE booking_status = 'Success';

-- Q6) Revenue lost due to failures

SELECT ROUND(SUM(booking_value), 2) AS revenue_lost
FROM bookings
WHERE booking_status != 'Success';


-- Q7) Revenue loss by failure type

SELECT
    booking_status,
    ROUND(SUM(booking_value), 2) AS revenue_lost
FROM bookings
WHERE booking_status != 'Success'
GROUP BY booking_status
ORDER BY revenue_lost DESC;

# OPERATIONAL FRICTION

-- Q8) Cancellation rate by vehicle type

SELECT vehicle_type,
ROUND(
SUM(
CASE WHEN booking_status != 'Success' AND booking_status <> "Driver Not Found" THEN 1 ELSE 0 END) 
* 100.0 / COUNT(*), 2) AS cancellation_rate
FROM bookings
GROUP BY vehicle_type
ORDER BY cancellation_rate DESC;

-- Q9) Top cancellation reasons (customer)

SELECT
    canceled_rides_by_customer,
    COUNT(*) AS total
FROM bookings
WHERE canceled_rides_by_customer IS NOT NULL
  AND canceled_rides_by_customer <> 'NA'
  AND canceled_rides_by_customer <> ''
GROUP BY canceled_rides_by_customer
ORDER BY total DESC
LIMIT 3;


-- Q10) Top cancellation reasons (driver)

SELECT
    canceled_rides_by_driver,
    COUNT(*) AS total
FROM bookings
WHERE canceled_rides_by_driver IS NOT NULL
  AND canceled_rides_by_driver <> 'NA'
GROUP BY canceled_rides_by_driver
ORDER BY total DESC
LIMIT 3;


# TIME & QUALITY INSIGHTS

-- Q11) Risky hours (high cancellation rate)

SELECT
    HOUR(`Time`) AS hour,
    ROUND(
        SUM(CASE WHEN booking_status != 'Success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS cancellation_rate
FROM bookings
GROUP BY hour
ORDER BY cancellation_rate DESC
LIMIT 3;

-- Q12) Which hours are riskiest for ride failures?

SELECT
    hour,
    cancellation_rate,
    RANK() OVER (ORDER BY cancellation_rate DESC) AS risk_rank
FROM (
    SELECT
        HOUR(`Time`) AS hour,
        SUM(CASE WHEN booking_status != 'Success' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*) AS cancellation_rate
    FROM bookings
    GROUP BY hour
) t;


-- Q13) Quality vs payoff (ratings vs revenue)

SELECT
    vehicle_type,
    ROUND(AVG(driver_ratings), 2) AS avg_rating,
    ROUND(SUM(booking_value), 2) AS total_revenue
FROM bookings
WHERE booking_status = 'Success'
GROUP BY vehicle_type;

# PRIORITIZATION (WHAT TO FIX FIRST)

-- Q14) Final fix priority (decision table)

SELECT
    issue_type,
    revenue_impact
FROM (
    SELECT
        CASE
            WHEN booking_status = 'Canceled by Driver' THEN 'Driver Issue'
            WHEN booking_status = 'Canceled by Customer' THEN 'Customer Issue'
            ELSE 'Other'
        END AS issue_type,
        SUM(booking_value) AS revenue_impact
    FROM bookings
    WHERE booking_status != 'Success'
    GROUP BY issue_type
) t
ORDER BY revenue_impact DESC;



-- Q15) Retrieve all successful bookings:
CREATE VIEW Successful_Bookings AS
SELECT * 
FROM bookings 
WHERE Booking_Status = 'Success';

-- Created a View 
SELECT * 
FROM Successful_Bookings;

-- Q16) Find the average ride distance for each vehicle type:
SELECT Vehicle_Type, AVG(Ride_Distance) AS AVG_Distance
FROM bookings
GROUP BY Vehicle_Type;

-- Q17) Get the total number of cancelled rides by customers:
SELECT COUNT(*)
FROM bookings
WHERE Booking_Status = 'Canceled by Customer';

-- Q18) List the top 5 customers who booked the highest number of rides:
SELECT Customer_ID, COUNT(Booking_ID) AS total_rides
FROM bookings
GROUP BY Customer_ID
ORDER BY total_rides DESC LIMIT 5;

-- Q19) Get the number of rides cancelled by drivers due to personal and car-related issues:
SELECT COUNT(*)
FROM bookings
WHERE Canceled_Rides_by_Driver = 'Personal & Car related issue';

-- Q20) Find the maximum and minimum driver ratings for Prime Sedan bookings:
SELECT  MAX(Driver_Ratings) AS max_rating, MIN(Driver_Ratings) AS min_rating
FROM bookings
WHERE Vehicle_Type =  'Prime Sedan';

-- Q21) Retrieve all rides where payment was made using UPI:
SELECT COUNT(*)
FROM bookings 
WHERE Payment_Method = 'UPI';

-- Q22) Find the average customer rating per vehicle type:
SELECT Vehicle_type, ROUND(AVG(Customer_Rating),2) AS avg_customer_ratings
FROM bookings
GROUP BY Vehicle_Type;

-- Q23) Calculate the total booking value of rides completed successfully:
SELECT SUM(Booking_Value) AS total_booking_value
FROM bookings
WHERE Booking_Status = 'Success';

-- Q24)  List all incomplete rides along with the reason:
SELECT Booking_ID, Incomplete_Rides_Reason 
FROM bookings 
WHERE Incomplete_Rides = 'Yes';
