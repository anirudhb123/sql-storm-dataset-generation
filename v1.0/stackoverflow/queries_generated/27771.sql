WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Questions created in the last year
),
TopQuestions AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10  -- Top 10 questions
),
CommentsData AS (
    SELECT 
        c.PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
BadgesData AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        tq.PostId,
        tq.Title,
        tq.CreationDate,
        tq.ViewCount,
        tq.Score,
        tq.OwnerDisplayName,
        COALESCE(cd.TotalComments, 0) AS TotalComments,
        bd.TotalBadges
    FROM 
        TopQuestions tq
    LEFT JOIN 
        CommentsData cd ON tq.PostId = cd.PostId
    LEFT JOIN 
        BadgesData bd ON tq.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = bd.UserId)
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.TotalComments,
    ps.TotalBadges
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
This query benchmarks string processing through various operations involving ranking questions, aggregating comments, and counting badges in the context of a Stack Overflow-like schema. It uses common table expressions (CTEs) to handle intermediary steps and provides a final list of the top questions with relevant metrics for analysis.
