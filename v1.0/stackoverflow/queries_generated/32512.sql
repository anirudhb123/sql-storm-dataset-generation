WITH RecursivePostHierarchy AS (
    -- CTE to get the hierarchy of posts (Questions and their Answers)
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Level,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        Level + 1,
        p.CreationDate
    FROM 
        Posts p
    INNER JOIN 
        Posts parent ON p.ParentId = parent.Id
    WHERE 
        parent.PostTypeId = 1  -- Only join to Questions
),
PostStatistics AS (
    -- CTE to calculate statistics for the posts
    SELECT 
        rph.PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        RecursivePostHierarchy rph
    LEFT JOIN 
        Comments c ON rph.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rph.PostId = v.PostId
    GROUP BY 
        rph.PostId
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        ps.CommentCount,
        ps.VoteCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        DENSE_RANK() OVER (ORDER BY ps.VoteCount DESC) AS VoteRank,
        p.CreationDate,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) AS AgeInSeconds
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostStatistics ps ON p.Id = ps.PostId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.OwnerDisplayName,
    pa.CommentCount,
    pa.VoteCount,
    pa.UpVoteCount,
    pa.DownVoteCount,
    pa.VoteRank,
    CASE 
        WHEN pa.AgeInSeconds < 86400 THEN 'New'
        WHEN pa.AgeInSeconds < 604800 THEN 'Recent'
        ELSE 'Old'
    END AS AgeCategory,
    (SELECT 
         COUNT(DISTINCT b.Id)
     FROM 
         Badges b
     WHERE 
         b.UserId = pa.OwnerUserId) AS BadgeCount,
    COALESCE((SELECT 
                  GROUP_CONCAT(DISTINCT t.TagName)
              FROM 
                  Tags t 
              WHERE 
                  t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(p.Tags, ','))) 
              LIMIT 5), 'No Tags') AS TopTags
FROM 
    PostAnalytics pa
WHERE 
    pa.VoteCount > 0
ORDER BY 
    pa.VoteRank,
    pa.CreationDate DESC
LIMIT 100;
