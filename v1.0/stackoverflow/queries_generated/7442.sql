WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        STUFF((SELECT ', ' + t.TagName
               FROM Tags t 
               WHERE p.Tags LIKE '%<'+ t.TagName + '>%'
               FOR XML PATH('')), 1, 2, '') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    WHERE 
        p.CreationDate > DATEADD(YEAR, -1, GETDATE()) AND 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.RankScore,
    rp.TagsList,
    COALESCE(uv.UpVotes, 0) AS UpVotes,
    COALESCE(uv.DownVotes, 0) AS DownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVotes uv ON rp.PostId = uv.PostId
WHERE 
    rp.RankScore <= 10
ORDER BY 
    rp.RankScore, rp.ViewCount DESC;
