
SELECT COUNT(*) AS TotalPosts
FROM Posts
GROUP BY Posts.Id; -- assuming Id is the unique identifier for the Posts table
