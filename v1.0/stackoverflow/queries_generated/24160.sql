WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswerCount,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
BadgesStats AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS HistoryCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseOpenHistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS TagRank
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
)
SELECT 
    u.DisplayName,
    us.QuestionCount,
    us.AnswerCount,
    us.AcceptedAnswerCount,
    us.TotalPosts,
    COALESCE(bs.BadgeCount, 0) AS BadgeCount,
    COALESCE(bs.BadgeNames, 'None') AS BadgeNames,
    COALESCE(phs.HistoryCount, 0) AS PostHistoryCount,
    COALESCE(phs.CloseOpenHistoryCount, 0) AS CloseOpenHistoryCount,
    pt.TagName,
    pt.PostCount
FROM 
    Users u
LEFT JOIN 
    UserPostStats us ON u.Id = us.UserId
LEFT JOIN 
    BadgesStats bs ON u.Id = bs.UserId
LEFT JOIN 
    PostHistoryStats phs ON u.Id = phs.UserId
LEFT JOIN 
    PopularTags pt ON pt.TagRank <= 5 -- Top 5 popular tags only
WHERE 
    (us.QuestionCount > 0 AND us.AnswerCount > 0) 
    OR (bs.BadgeCount > 0)
ORDER BY 
    us.QuestionCount DESC, 
    us.AnswerCount DESC, 
    CASE WHEN phs.CloseOpenHistoryCount IS NULL THEN 1 ELSE 0 END,
    pt.PostCount DESC; 

This SQL query includes several interesting constructs:
- Common Table Expressions (CTEs) for modular organization of complex calculations, making the query easier to follow and manage.
- Use of `COALESCE` for handling potential NULL values, thus ensuring that results can still provide meaningful data points.
- Aggregate functions and window functions are employed to derive statistics for users, badges, post history, and tags.
- A subquery `LEFT JOIN` to filter only those users who have posted questions and answers or hold badges.
- The additional filtering and ranking of popular tags enhances the complexity of the query while providing relevant context to the main user statistics.
