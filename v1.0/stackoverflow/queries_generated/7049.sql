WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        COALESCE(q.AnswerCount, 0) AS AnswerCount,
        COALESCE(q.CommentCount, 0) AS CommentCount,
        COALESCE(q.FavoriteCount, 0) AS FavoriteCount,
        COALESCE(l.LinkCount, 0) AS LinkCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount,
            SUM(CASE WHEN CommentCount IS NOT NULL THEN CommentCount ELSE 0 END) AS CommentCount,
            SUM(CASE WHEN FavoriteCount IS NOT NULL THEN FavoriteCount ELSE 0 END) AS FavoriteCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) q ON p.Id = q.ParentId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS LinkCount 
        FROM 
            PostLinks 
        GROUP BY 
            PostId
    ) l ON p.Id = l.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '>')) AS t(TagName)
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.Score, p.ViewCount
)
SELECT 
    PostId,
    Title,
    PostTypeId,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    LinkCount,
    UpVoteCount,
    DownVoteCount,
    Tags
FROM 
    PostStats
ORDER BY 
    Score DESC, 
    ViewCount DESC
LIMIT 100;
