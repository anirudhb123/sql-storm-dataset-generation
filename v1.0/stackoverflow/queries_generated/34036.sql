WITH RecursivePostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
RankedPosts AS (
    SELECT 
        ph.PostId,
        ph.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY ph.OwnerUserId ORDER BY COUNT(a.Id) DESC) AS UserPostRank
    FROM 
        RecursivePostHierarchy ph
    LEFT JOIN 
        Posts a ON ph.PostId = a.ParentId
    LEFT JOIN 
        Votes v ON ph.PostId = v.PostId
    LEFT JOIN 
        Users u ON ph.OwnerUserId = u.Id
    GROUP BY 
        ph.PostId, ph.Title, ph.OwnerUserId, u.DisplayName
),
PostAnalytics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        COALESCE(rp.Upvotes, 0) - COALESCE(rp.Downvotes, 0) AS NetVotes,
        CASE 
            WHEN rp.UserPostRank = 1 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostRankCategory
    FROM 
        RankedPosts rp
)
SELECT 
    pa.Title,
    pa.OwnerDisplayName,
    pa.AnswerCount,
    pa.NetVotes,
    pa.PostRankCategory,
    COALESCE(ph.ClosedDate, 'No closure') AS ClosureStatus,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    PostAnalytics pa
LEFT JOIN 
    Posts ph ON pa.PostId = ph.Id
LEFT JOIN 
    Comments c ON pa.PostId = c.PostId
WHERE 
    pa.AnswerCount > 5
GROUP BY 
    pa.PostId, pa.Title, pa.OwnerDisplayName, pa.AnswerCount, pa.NetVotes, pa.PostRankCategory, ph.ClosedDate
ORDER BY 
    pa.NetVotes DESC, pa.AnswerCount DESC;

This query performs a series of operations to generate a comprehensive report on posts with more than five answers. It uses recursive CTEs to traverse the post hierarchy, identifies top posts per user using window functions for ranking, calculates net votes by subtracting downvotes from upvotes, and includes closure status and comment counts for additional insights. The final output is ordered by net votes and answer count, showcasing the most impactful posts.
