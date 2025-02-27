WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ue.UserId,
        ue.DisplayName AS UserDisplayName,
        ue.PostCount,
        ue.TotalBounty,
        ue.Upvotes,
        ue.Downvotes,
        ue.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY rp.PostId ORDER BY rp.CreationDate DESC) AS PostRank
    FROM 
        RecursivePosts rp
    JOIN 
        UserEngagement ue ON rp.OwnerUserId = ue.UserId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.UserDisplayName,
    pa.PostCount,
    pa.TotalBounty,
    pa.Upvotes,
    pa.Downvotes,
    pa.CommentCount,
    (pa.Upvotes - pa.Downvotes) AS NetVotes,
    CASE 
        WHEN pa.Score >= 10 THEN 'High Score'
        WHEN pa.Score BETWEEN 5 AND 9 THEN 'Medium Score'
        ELSE 'Low Score' 
    END AS ScoreClassification
FROM 
    PostActivity pa
WHERE 
    pa.PostRank = 1
ORDER BY 
    pa.ViewCount DESC, pa.CreationDate DESC
LIMIT 50;

This SQL query does the following:
- Uses a recursive CTE to create a hierarchy of posts, capturing both parent and child posts.
- Performs a second CTE (`UserEngagement`) that aggregates user activity, such as post counts, total bounties, upvotes, downvotes, and comment counts for each user.
- Combines these into a `PostActivity` CTE that gives a detailed view of each post along with the user information and calculates net votes.
- Returns a final dataset ordered by view count and creation date, including classification of scores (High, Medium, Low). The result is limited to the top 50 entries based on view count.
