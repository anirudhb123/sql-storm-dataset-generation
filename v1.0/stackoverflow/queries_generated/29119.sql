WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.UpVotes,
        p.DownVotes,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS DistinctTags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        rp.DistinctTags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5  -- Top 5 posts by type
),

PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(UPT.UpVotes, 0) AS UpVotes,
        COALESCE(DPT.DownVotes, 0) AS DownVotes,
        COALESCE(cm.CommentCount, 0) AS CommentCount,
        COALESCE(ph.PostHistoryCount, 0) AS PostHistoryCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS UpVotes
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2  -- Upvotes
        GROUP BY 
            PostId
    ) UPT ON p.Id = UPT.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS DownVotes
        FROM 
            Votes
        WHERE 
            VoteTypeId = 3  -- Downvotes
        GROUP BY 
            PostId
    ) DPT ON p.Id = DPT.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) cm ON p.Id = cm.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS PostHistoryCount
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.CommentCount,
    pm.PostHistoryCount,
    tp.DistinctTags
FROM 
    TopPosts tp
JOIN 
    PostMetrics pm ON tp.PostId = pm.PostId
ORDER BY 
    tp.ViewCount DESC, pm.UpVotes DESC, tp.CreationDate DESC;
