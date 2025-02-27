WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE()) -- last 6 months
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.UpVotes >= 50 THEN 'Very Popular'
            WHEN rp.UpVotes BETWEEN 20 AND 49 THEN 'Popular'
            ELSE 'Needs Attention'
        END AS PopularityCategory,
        ROW_NUMBER() OVER (PARTITION BY rp.PopularityCategory ORDER BY rp.ViewCount DESC) AS PopularityRank
    FROM 
        RankedPosts rp
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.UpVotes,
    t.DownVotes,
    t.CommentCount,
    t.PopularityCategory,
    ph.Comment AS PostEditComment,
    CASE 
        WHEN ph.PostHistoryTypeId IS NOT NULL THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus
FROM 
    TopPosts t
LEFT JOIN 
    PostHistory ph ON t.PostId = ph.PostId AND ph.CreationDate = (
        SELECT MAX(ph_inner.CreationDate) 
        FROM PostHistory ph_inner 
        WHERE ph_inner.PostId = t.PostId AND ph_inner.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edits
    )
WHERE 
    t.PopularityRank <= 5 -- Top 5 per popularity category
ORDER BY 
    t.PopularityCategory, t.PopularityRank;

This query tracks popular posts over the last six months, categorizes them based on vote counts, and retrieves additional context concerning the most recent edits on those posts. It employs Common Table Expressions (CTEs) for organization, window functions for ranking, and correlates subqueries for ensuring details about edits are present while handling multiple outer joins to gather comprehensive information, including NULL logic for managing posts without votes or comments.
