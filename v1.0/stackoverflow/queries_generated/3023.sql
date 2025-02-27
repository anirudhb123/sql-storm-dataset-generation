WITH PostScore AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        PostScore
    WHERE 
        PostRank <= 5
    ORDER BY 
        Score DESC
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        LATERAL (SELECT ARRAY(SELECT UNNEST(string_to_array(p.Tags, '><')))) AS tags ON TRUE
    JOIN 
        Tags t ON t.TagName = ANY(tags)
    GROUP BY 
        p.Id
)
SELECT 
    tp.OwnerDisplayName,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(pt.Tags, 'No Tags') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    PostTags pt ON tp.PostId = pt.PostId
UNION ALL
SELECT 
    'Total',
    COUNT(*),
    SUM(Score),
    SUM(ViewCount),
    SUM(CommentCount),
    SUM(UpVotes),
    SUM(DownVotes),
    NULL
FROM 
    TopPosts
ORDER BY 
    Score DESC NULLS LAST;
