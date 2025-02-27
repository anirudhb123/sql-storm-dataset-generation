WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id
), RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounty,
        BadgeCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY Reputation DESC, TotalBounty DESC) AS UserRank
    FROM 
        UserStats
), QuestionDetails AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(Answers.AnswerCount, 0) AS AnswerCount,
        COALESCE(Comments.CommentCount, 0) AS CommentCount,
        COALESCE(LastEdit.LastEditDate, p.CreationDate) AS LastActive
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
    ) Answers ON Answers.ParentId = p.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) Comments ON Comments.PostId = p.Id
    LEFT JOIN (
        SELECT 
            Id, 
            LastEditDate 
        FROM 
            Posts 
        WHERE 
            LastEditDate IS NOT NULL
    ) LastEdit ON LastEdit.Id = p.Id
    WHERE 
        p.PostTypeId = 1
    ORDER BY 
        p.CreationDate DESC
), PostsWithLinks AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        pl.RelatedPostId,
        pl.CreationDate AS LinkCreationDate,
        lt.Name AS LinkType
    FROM 
        Posts p
    JOIN 
        PostLinks pl ON pl.PostId = p.Id
    JOIN 
        LinkTypes lt ON lt.Id = pl.LinkTypeId
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation AS UserReputation,
    qd.QuestionId,
    qd.Title AS QuestionTitle,
    qd.ViewCount AS QuestionViews,
    qd.AnswerCount AS TotalAnswers,
    qd.CommentCount AS TotalComments,
    qd.LastActive,
    pl.PostTitle AS LinkedPostTitle,
    pl.LinkType
FROM 
    RankedUsers ru
JOIN 
    QuestionDetails qd ON ru.UserId = qd.OwnerUserId
LEFT JOIN 
    PostsWithLinks pl ON pl.PostId = qd.QuestionId
WHERE 
    ru.Reputation > 1000
ORDER BY 
    ru.UserRank, qd.ViewCount DESC
LIMIT 100;
