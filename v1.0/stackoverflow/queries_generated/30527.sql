WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        Score,
        OwnerUserId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.Id
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        CASE 
            WHEN Reputation > 1000 THEN 'High'
            WHEN Reputation > 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM 
        Users
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
ActivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.Score,
        ph.CreationDate,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        u.ReputationLevel
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteCounts v ON p.Id = v.PostId
    LEFT JOIN 
        RecursivePostHierarchy ph ON p.Id = ph.Id
    LEFT JOIN 
        UserReputation u ON p.OwnerUserId = u.UserId
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, GETDATE()) 
)
SELECT 
    ap.Title,
    ap.Score,
    ap.UpVotes,
    ap.DownVotes,
    ap.ReputationLevel,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE 
            WHEN c.Score > 0 THEN 1 
            ELSE 0 
        END) AS PositiveCommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    ActivePosts ap
LEFT JOIN 
    Comments c ON ap.Id = c.PostId
LEFT JOIN 
    LATERAL (SELECT 
                  STRING_TO_ARRAY(SUBSTRING(ap.Tags, 2, LENGTH(ap.Tags)-2), '><') AS TagName 
              ) t ON TRUE
LEFT JOIN 
    Tags tg ON t.TagName = tg.TagName
WHERE 
    ap.Score > 10
GROUP BY 
    ap.Id, ap.Title, ap.Score, ap.UpVotes, ap.DownVotes, ap.ReputationLevel
ORDER BY 
    ap.Score DESC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY;

This SQL query leverages multiple constructs, such as CTEs for recursive post hierarchies and user reputation levels, window functions for counting votes, NULL logic for handling left joins, and string aggregation for collating tags. The primary goal is to provide an insightful performance benchmark through a variety of post metrics in relation to user reputation within the last 30 days.
