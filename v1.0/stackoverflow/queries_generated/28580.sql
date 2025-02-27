WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikiPosts,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        IFNULL(CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', -1), '<', 1) AS CHAR), 'No Tags') AS MainTag
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 DAY'
    ORDER BY 
        p.ViewCount DESC
    LIMIT 10
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalTagWikiPosts,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.MainTag
FROM 
    UserActivity ua
JOIN 
    TopPosts tp ON tp.PostId IN (
        SELECT PostId FROM Posts WHERE OwnerUserId = ua.UserId
    )
ORDER BY 
    ua.TotalPosts DESC, 
    tp.ViewCount DESC;
