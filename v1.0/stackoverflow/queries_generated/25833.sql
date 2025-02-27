WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerDisplayName,
        p.ViewCount,
        p.AnswerCount,
        p.Tags
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '> <')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        PostDetails
    GROUP BY 
        TagName
),
PopularTags AS (
    SELECT 
        tc.TagName,
        tc.TagCount
    FROM 
        TagCounts tc
    ORDER BY 
        tc.TagCount DESC
    LIMIT 5
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCreated,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCreated
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserPosts AS (
    SELECT 
        ua.DisplayName,
        ua.PostsCreated,
        ua.AnswersCreated,
        ua.QuestionsCreated,
        STRING_AGG(DISTINCT pt.TagName, ', ') AS TagsUsed
    FROM 
        UserActivity ua
    JOIN 
        PostDetails pd ON ua.UserId = pd.OwnerUserId
    JOIN 
        TagCounts pt ON pt.TagName = ANY(string_to_array(substring(pd.Tags, 2, length(pd.Tags)-2), '> <'))
    GROUP BY 
        ua.DisplayName, ua.PostsCreated, ua.AnswersCreated, ua.QuestionsCreated
),
FinalReport AS (
    SELECT 
        up.DisplayName AS User,
        up.PostsCreated,
        up.AnswersCreated,
        up.QuestionsCreated,
        COALESCE(pt.TagName, 'No Tags') AS PopularTag,
        COUNT(pd.PostId) AS RelatedPosts
    FROM 
        UserPosts up
    LEFT JOIN 
        PopularTags pt ON TRUE
    LEFT JOIN 
        PostDetails pd ON TRUE
    GROUP BY 
        up.DisplayName, up.PostsCreated, up.AnswersCreated, up.QuestionsCreated, pt.TagName
)
SELECT 
    User,
    PostsCreated,
    AnswersCreated,
    QuestionsCreated,
    PopularTag,
    RelatedPosts
FROM 
    FinalReport
ORDER BY 
    PostsCreated DESC;
