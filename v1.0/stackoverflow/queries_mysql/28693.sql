
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN 
        (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t, (SELECT @row := 0) r) n ON LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        @rank := IF(@prev = PostCount, @rank, @rank + 1) AS Rank,
        @prev := PostCount
    FROM 
        TagCounts,
        (SELECT @rank := 0, @prev := NULL) r
    WHERE 
        PostCount >= 10 
    ORDER BY 
        PostCount DESC
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(b.Class) AS TotalBadgeScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserMetrics AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.QuestionCount,
        us.Upvotes,
        us.Downvotes,
        us.TotalBadgeScore,
        (us.Upvotes - us.Downvotes) AS Score,
        @user_rank := IF(@user_prev = (us.Upvotes - us.Downvotes + us.TotalBadgeScore), @user_rank, @user_rank + 1) AS UserRank,
        @user_prev := (us.Upvotes - us.Downvotes + us.TotalBadgeScore)
    FROM 
        UserScores us,
        (SELECT @user_rank := 0, @user_prev := NULL) r
)
SELECT 
    tt.TagName,
    um.DisplayName,
    um.QuestionCount,
    um.Upvotes,
    um.Downvotes,
    um.TotalBadgeScore,
    um.Score,
    um.UserRank
FROM 
    TopTags tt
JOIN 
    Posts p ON p.Tags LIKE CONCAT('%', tt.TagName, '%')
JOIN 
    UserMetrics um ON p.OwnerUserId = um.UserId
WHERE 
    um.UserRank <= 10 
ORDER BY 
    tt.TagName, um.UserRank;
