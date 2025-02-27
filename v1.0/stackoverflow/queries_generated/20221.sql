WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(v.VoteCount, 0) DESC) AS Rank,
        u.Reputation,
        u.DisplayName AS UserDisplayName
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId IN (2, 3) -- Only upvotes and downvotes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Posts from the last 30 days
),

RecentlyEditedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '7 days' 
        AND ph.PostHistoryTypeId IN (4, 5, 6) -- Edited Title, Body, Tags
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.VoteCount,
    rp.Rank,
    rp.UserDisplayName,
    COALESCE(re.EditDate, 'No Recent Edits') AS RecentEditDate,
    COALESCE(re.Comment, 'N/A') AS EditComment,
    COALESCE(re.PostHistoryType, 'No Recent Edits') AS HistoryType,
    CASE 
        WHEN rp.VoteCount > 100 THEN 'Hot Post'
        WHEN rp.Reputation > 1000 THEN 'Seasoned Author'
        ELSE 'Newbie' 
    END AS UserCategory,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = rp.PostId) THEN 'Has Comments'
        ELSE 'No Comments' 
    END AS CommentStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentlyEditedPosts re ON rp.PostId = re.PostId
WHERE 
    rp.Rank <= 5 -- Top 5 posts by votes in each post type
    AND rp.PostTypeId = 1 -- Only Questions
ORDER BY 
    rp.VoteCount DESC, rp.CreationDate DESC;

-- Handling NULL values and using string expressions
SELECT 
    COUNT(*) AS TotalPosts,
    SUM(CASE WHEN rp.VoteCount IS NULL THEN 1 ELSE 0 END) AS PostsWithNoVotes
FROM 
    RankedPosts rp;

-- Additional complexity: Set operator
UNION ALL
SELECT 
    COUNT(*) AS TotalEditedPosts,
    NULL AS PostsWithNoVotes
FROM 
    RecentlyEditedPosts;
