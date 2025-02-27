WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(ah.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        t.TagName
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) ah ON p.Id = ah.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%' 
    WHERE 
        p.PostTypeId = 1 -- questions
        AND p.LastActivityDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, t.TagName
),
RankedPosts AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        AnswerCount,
        CommentCount,
        VoteCount,
        TagName,
        RANK() OVER (PARTITION BY TagName ORDER BY Score DESC, ViewCount DESC) AS PostRank
    FROM 
        PostStats
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    rp.VoteCount,
    rp.TagName
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.TagName, rp.PostRank;
