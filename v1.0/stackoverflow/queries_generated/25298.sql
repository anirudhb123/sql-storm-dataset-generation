WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(p.Tags, ',') AS tagArray ON true
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tagArray)
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score,
        rp.Tags,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    trp.Title,
    trp.CreationDate,
    trp.ViewCount,
    trp.AnswerCount,
    trp.Score,
    trp.Tags,
    trp.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Comments c ON trp.PostId = c.PostId
LEFT JOIN 
    Votes v ON trp.PostId = v.PostId
GROUP BY 
    trp.PostId, trp.Title, trp.CreationDate, trp.ViewCount, trp.AnswerCount, trp.Score, trp.Tags, trp.OwnerDisplayName
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
