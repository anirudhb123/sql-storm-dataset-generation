WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days' -- Recent posts
    GROUP BY 
        p.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 -- Top 5 based on creation date
)
SELECT 
    pp.Title,
    pp.OwnerDisplayName,
    pp.CommentCount,
    pp.UpVotes,
    pp.DownVotes,
    (pp.UpVotes - pp.DownVotes) AS Score,
    pht.Name AS PostHistoryType
FROM 
    PopularPosts pp
JOIN 
    PostHistory ph ON pp.PostId = ph.PostId
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    ph.CreationDate > CURRENT_DATE - INTERVAL '7 days' -- Recent activity in the past week
ORDER BY 
    Score DESC, pp.CommentCount DESC;
