
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(p.Tags, '>')) t ON TRUE
    WHERE 
        p.CreationDate >= TIMESTAMPADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, pt.Name, u.DisplayName
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        LISTAGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN c.Name END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON CAST(ph.Comment AS INT) = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.CreationDate,
    rp.Tags,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    cp.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
