WITH RecentVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '30 days')
    GROUP BY 
        p.Id
),
PostMetrics AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(rv.Upvotes, 0) AS Upvotes,
        COALESCE(rv.Downvotes, 0) AS Downvotes,
        (COALESCE(rv.Upvotes, 0) - COALESCE(rv.Downvotes, 0)) AS NetVotes,
        p.CreationDate,
        DENSE_RANK() OVER (ORDER BY COALESCE(rv.Upvotes, 0) DESC) AS VoteRank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        RecentVotes rv ON p.Id = rv.PostId
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
TopPosts AS (
    SELECT 
        pm.Id,
        pm.Title,
        pm.ViewCount,
        pm.Upvotes,
        pm.Downvotes,
        pm.NetVotes,
        pm.CreationDate,
        pm.VoteRank,
        pm.CommentCount,
        (SELECT STRING_AGG(t.TagName, ', ') 
         FROM Tags t 
         WHERE t.Id = ANY (SELECT DISTINCT unnest(string_to_array(p.Tags, '><')::int[]))) 
         GROUP BY 1) AS TagsList
    FROM 
        PostMetrics pm
    WHERE 
        pm.NetVotes > 0
        AND pm.CommentCount > 5
),
RankedPosts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY VoteRank ORDER BY ViewCount DESC) AS ViewRank
    FROM 
        TopPosts
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Upvotes,
    rp.Downvotes,
    rp.NetVotes,
    rp.CreationDate,
    rp.TagsList,
    CASE 
        WHEN rp.VoteRank = 1 THEN 'Top Vote Getter'
        WHEN rp.ViewRank <= 5 THEN 'Popular Posts'
        ELSE 'Standard Posts'
    END AS PostCategory
FROM 
    RankedPosts rp
WHERE 
    rp.CommentCount BETWEEN 5 AND 100
    AND rp.CreationDate < (CURRENT_TIMESTAMP - INTERVAL '1 week')
ORDER BY 
    rp.ViewCount DESC, rp.NetVotes DESC
LIMIT 50;

-- NOTE: The PARTITION BY VoteRank and STRING_AGG() function assumes PostgreSQL syntax and functionality.
