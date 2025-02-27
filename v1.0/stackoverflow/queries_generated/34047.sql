WITH RecursivePostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.AnswerCount,
        Posts.ViewCount,
        Users.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY Posts.Id ORDER BY Posts.CreationDate DESC) AS RowNum
    FROM 
        Posts
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.PostTypeId = 1 -- Only questions
),  -- CTE to fetch post stats and user reputation

PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),  -- CTE to summarize votes for posts

MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(ph.Comment IS NOT NULL, 0)) AS Edits,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM 
        Users AS u
    JOIN 
        Posts AS p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory AS ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5  -- Only consider users with more than 5 posts
)

SELECT 
    rps.PostId,
    rps.Title,
    rps.CreationDate,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    rps.Score,
    rps.ViewCount,
    rps.OwnerReputation,
    mau.UserId,
    mau.DisplayName AS MostActiveUser,
    mau.PostCount AS ActiveUserPostCount,
    mau.Edits AS UserEdits,
    mau.Rank AS UserRank
FROM 
    RecursivePostStats AS rps
LEFT JOIN 
    PostVoteSummary AS pvs ON rps.PostId = pvs.PostId
LEFT JOIN 
    MostActiveUsers AS mau ON rps.OwnerUserId = mau.UserId
WHERE 
    rps.RowNum = 1  -- Only get latest post stats
ORDER BY 
    rps.CreationDate DESC,
    rps.Score DESC;

-- The above query is structured to perform a performance benchmark based on:
-- A recursive CTE to get post stats,
-- A vote summary CTE,
-- A CTE to identify the most active users,
-- Using outer joins to get details from different tables,
-- Filtering and ranking users,
-- Displaying various calculated fields.
