
WITH PostCounts AS (
    SELECT
        DATE(CreationDate) AS PostDate,
        COUNT(*) AS TotalPosts
    FROM
        Posts
    GROUP BY
        DATE(CreationDate)
),
UserCounts AS (
    SELECT
        DATE(CreationDate) AS UserDate,
        COUNT(*) AS TotalUsers
    FROM
        Users
    GROUP BY
        DATE(CreationDate)
),
VoteCounts AS (
    SELECT
        DATE(CreationDate) AS VoteDate,
        COUNT(*) AS TotalVotes
    FROM
        Votes
    GROUP BY
        DATE(CreationDate)
)
SELECT
    COALESCE(p.PostDate, u.UserDate, v.VoteDate) AS ActivityDate,
    COALESCE(p.TotalPosts, 0) AS Posts,
    COALESCE(u.TotalUsers, 0) AS Users,
    COALESCE(v.TotalVotes, 0) AS Votes
FROM
    PostCounts p
LEFT JOIN
    UserCounts u ON p.PostDate = u.UserDate
LEFT JOIN
    VoteCounts v ON COALESCE(p.PostDate, u.UserDate) = v.VoteDate
UNION
SELECT
    COALESCE(p.PostDate, u.UserDate, v.VoteDate) AS ActivityDate,
    COALESCE(p.TotalPosts, 0) AS Posts,
    COALESCE(u.TotalUsers, 0) AS Users,
    COALESCE(v.TotalVotes, 0) AS Votes
FROM
    UserCounts u
LEFT JOIN
    PostCounts p ON p.PostDate = u.UserDate
LEFT JOIN
    VoteCounts v ON COALESCE(p.PostDate, u.UserDate) = v.VoteDate
WHERE
    p.PostDate IS NULL
UNION
SELECT
    COALESCE(p.PostDate, u.UserDate, v.VoteDate) AS ActivityDate,
    COALESCE(p.TotalPosts, 0) AS Posts,
    COALESCE(u.TotalUsers, 0) AS Users,
    COALESCE(v.TotalVotes, 0) AS Votes
FROM
    VoteCounts v
LEFT JOIN
    PostCounts p ON COALESCE(p.PostDate, u.UserDate) = v.VoteDate
LEFT JOIN
    UserCounts u ON p.PostDate = u.UserDate
WHERE
    p.PostDate IS NULL AND u.UserDate IS NULL
ORDER BY
    ActivityDate;
