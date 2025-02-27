
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        GROUP_CONCAT(DISTINCT p.OwnerDisplayName ORDER BY p.OwnerDisplayName SEPARATOR ', ') AS Contributors,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
),
TopContributors AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.DisplayName
    ORDER BY 
        BadgeCount DESC, TotalViews DESC
    LIMIT 10
),
PostAgeAnalysis AS (
    SELECT 
        p.Id,
        p.Title,
        TIMESTAMPDIFF(DAY, p.CreationDate, '2024-10-01 12:34:56') AS AgeInDays,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR) 
    GROUP BY 
        p.Id, p.Title
    HAVING 
        COUNT(c.Id) > 5 AND SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END)
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.Contributors,
    ts.QuestionCount,
    ts.AnswerCount,
    t.DisplayName AS TopContributorName,
    t.BadgeCount,
    t.TotalViews,
    pa.Title AS ActivePostTitle,
    pa.AgeInDays,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes
FROM 
    TagStatistics ts
JOIN 
    TopContributors t ON FIND_IN_SET(t.DisplayName, ts.Contributors) > 0
JOIN 
    PostAgeAnalysis pa ON ts.QuestionCount > 10
ORDER BY 
    ts.PostCount DESC, t.BadgeCount DESC, pa.AgeInDays;
