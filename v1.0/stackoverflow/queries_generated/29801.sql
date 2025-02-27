WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY substring(p.Tags FROM 1 FOR 10) ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Only considering Questions
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Only posts from the last year
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CreationDate,
        t.TagName
    FROM 
        RankedPosts rp
    JOIN 
        string_to_array(rp.Tags, '>') AS t(TagName) ON t.TagName IS NOT NULL
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per tag
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id
),
FinalOutput AS (
    SELECT 
        tq.PostId,
        tq.Title,
        tq.Score,
        tq.ViewCount,
        tq.AnswerCount,
        uq.UserId,
        uq.DisplayName AS UserDisplayName,
        uq.TotalVotes,
        uq.TotalComments
    FROM 
        TopQuestions tq
    LEFT JOIN 
        UserEngagement uq ON tq.PostId IN (
            SELECT PostId 
            FROM Votes 
            WHERE UserId = uq.UserId
        )
)
SELECT 
    PostId,
    Title,
    Score,
    ViewCount,
    AnswerCount,
    UserId,
    UserDisplayName,
    TotalVotes,
    TotalComments
FROM 
    FinalOutput
ORDER BY 
    Score DESC, ViewCount DESC;
