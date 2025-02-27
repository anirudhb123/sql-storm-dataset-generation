
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS tag,
        COUNT(*) AS post_count
    FROM 
        Posts
    JOIN 
        (SELECT 
             1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
             SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        tag
),

TopTags AS (
    SELECT 
        tag,
        post_count,
        @rank := @rank + 1 AS rank
    FROM 
        TagCounts, (SELECT @rank := 0) r
    ORDER BY 
        post_count DESC
),

UserEngagement AS (
    SELECT 
        u.Id AS user_id,
        u.DisplayName AS user_name,
        COUNT(DISTINCT p.Id) AS question_count,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS downvotes,
        COUNT(DISTINCT c.Id) AS comment_count
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),

TagUserEngagement AS (
    SELECT 
        tt.tag,
        ue.user_id,
        ue.user_name,
        ue.question_count,
        ue.upvotes,
        ue.downvotes,
        ue.comment_count,
        @user_rank := IF(@prev_tag = tt.tag, @user_rank + 1, 1) AS user_rank,
        @prev_tag := tt.tag
    FROM 
        TopTags tt
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', tt.tag, '%')
    JOIN 
        UserEngagement ue ON p.OwnerUserId = ue.user_id,
        (SELECT @user_rank := 0, @prev_tag := '') r
    ORDER BY 
        tt.tag, ue.upvotes DESC, ue.downvotes ASC
)

SELECT 
    tag,
    user_id,
    user_name,
    question_count,
    upvotes,
    downvotes,
    comment_count,
    user_rank
FROM 
    TagUserEngagement
WHERE 
    user_rank <= 3 
ORDER BY 
    tag, user_rank;
