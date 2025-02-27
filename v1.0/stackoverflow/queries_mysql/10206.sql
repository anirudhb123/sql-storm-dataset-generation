
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, pt.Name, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        VoteCount,
        PostType,
        OwnerDisplayName,
        @scoreRank := IF(@prevScore = Score, @scoreRank, @rowNum) AS ScoreRank,
        @rowNum := @rowNum + 1 AS rn,
        @prevScore := Score
    FROM 
        PostStats, (SELECT @scoreRank := 0, @rowNum := 0, @prevScore := NULL) AS vars
    ORDER BY 
        Score DESC
),
RankedView AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        VoteCount,
        PostType,
        OwnerDisplayName,
        ScoreRank,
        @viewRank := IF(@prevViewCount = ViewCount, @viewRank, @rowNumView) AS ViewRank,
        @rowNumView := @rowNumView + 1 AS rnView,
        @prevViewCount := ViewCount
    FROM 
        TopPosts, (SELECT @viewRank := 0, @rowNumView := 0, @prevViewCount := NULL) AS vars
    ORDER BY 
        ViewCount DESC
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    VoteCount,
    PostType,
    OwnerDisplayName,
    ScoreRank,
    ViewRank
FROM 
    RankedView
WHERE 
    ScoreRank <= 10 OR ViewRank <= 10
ORDER BY 
    Score DESC, ViewCount DESC;
