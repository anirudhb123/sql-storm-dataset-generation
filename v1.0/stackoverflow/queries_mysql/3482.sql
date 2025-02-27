
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
), PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '|', numbers.n), '|', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
         UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12) numbers  -- Change this range based on max tag count
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '|', '')) >= numbers.n - 1
    WHERE 
        CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        TagName
), PostStatistics AS (
    SELECT 
        p.*,
        COALESCE(ph.Comment, 'No close reason') AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS RecentActivity
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.UpVotes,
    ua.DownVotes,
    pt.TagName,
    pt.TagCount,
    ps.Title,
    ps.CloseReason,
    ps.CreationDate
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ua.UserId = ps.OwnerUserId
JOIN 
    PopularTags pt ON ps.Tags LIKE CONCAT('%', pt.TagName, '%')
WHERE 
    ua.ActivityRank <= 10
ORDER BY 
    ua.TotalPosts DESC, pt.TagCount DESC;
