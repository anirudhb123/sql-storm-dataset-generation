WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName, 
        count(*) AS PostCount
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName 
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount, 
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank 
    FROM 
        TagCounts 
    WHERE 
        PostCount > 1
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        array_agg(t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        TopTags tt ON tt.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
    GROUP BY 
        p.Id
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(coalesce(c.CommentCount, 0)) AS TotalComments,
        SUM(coalesce(v.VoteCount, 0)) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON c.PostId = p.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON v.PostId = p.Id
    GROUP BY 
        u.Id
)
SELECT 
    ud.UserId,
    ud.DisplayName,
    ud.TotalPosts,
    ud.TotalComments,
    ud.TotalVotes,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.Tags
FROM 
    UserEngagement ud
JOIN 
    PostDetails pd ON ud.UserId = pd.OwnerUserId
WHERE 
    ud.TotalPosts > 0
ORDER BY 
    ud.TotalVotes DESC, ud.TotalComments DESC, pd.CreationDate DESC;
