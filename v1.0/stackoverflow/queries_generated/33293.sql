WITH RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Select Questions
    UNION ALL
    SELECT 
        A.Id AS PostId,
        A.Title,
        A.CreationDate,
        A.Score,
        R.Level + 1
    FROM 
        Posts A
    INNER JOIN 
        RecursiveCTE R ON A.ParentId = R.PostId
    WHERE 
        A.PostTypeId = 2 -- Select Answers
)
, PostVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
, BadgeCount AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    R.PostId,
    R.Title,
    R.CreationDate,
    R.Score,
    COALESCE(PV.UpVotes, 0) AS UpVotes,
    COALESCE(PV.DownVotes, 0) AS DownVotes,
    BC.TotalBadges,
    R.Level
FROM 
    RecursiveCTE R
LEFT JOIN 
    PostVotes PV ON R.PostId = PV.PostId
LEFT JOIN 
    Users U ON R.OwnerUserId = U.Id
LEFT JOIN 
    BadgeCount BC ON U.Id = BC.UserId
WHERE 
    R.Score > 0 
    AND R.CreationDate >= CURRENT_DATE - INTERVAL '1 week' 
ORDER BY 
    R.Score DESC, 
    R.CreationDate DESC 
LIMIT 100;

-- Explanation:
-- 1. RecursiveCTE: This Common Table Expression (CTE) selects questions and their corresponding answers, forming a hierarchy.
-- 2. PostVotes: This CTE aggregates votes for each post, calculating the total upvotes and downvotes.
-- 3. BadgeCount: This CTE counts the total badges per user.
-- 4. The final SELECT statement combines the data from the CTEs and joins with Users to get user IDs with their badges, filtering for posts with a positive score created within the last week and ordering them based on score and creation date.
