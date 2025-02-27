WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
RankedPosts AS (
    SELECT 
        pd.*, 
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS Rank
    FROM 
        PostDetails pd
),
ClosedPosts AS (
    SELECT 
        DISTINCT p.Id AS ClosedPostId
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.CommentCount,
    rp.Tags,
    CASE WHEN cp.ClosedPostId IS NOT NULL THEN 'Yes' ELSE 'No' END AS IsClosed
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.ClosedPostId
WHERE 
    rp.Rank <= 50
ORDER BY 
    rp.Rank;
