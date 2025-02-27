WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        t.TagName
),
UserStatistics AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersProvided,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastActivityDate,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.Comment
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Closed, Reopened, Deleted, Undeleted
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.UpVotes,
    ts.DownVotes,
    us.DisplayName AS TopUser,
    us.PostsCreated,
    us.QuestionsAsked,
    us.AnswersProvided,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    pa.Title,
    pa.LastActivityDate,
    pa.HistoryDate,
    pa.Comment
FROM 
    TagStatistics ts
JOIN 
    (
        SELECT 
            DisplayName,
            ROW_NUMBER() OVER (ORDER BY SUM(DISTINCT p.Id) DESC) AS UserRank
        FROM 
            Users u
        JOIN 
            Posts p ON p.OwnerUserId = u.Id
        GROUP BY 
            DisplayName
    ) user_rank ON user_rank.UserRank = 1
JOIN 
    UserStatistics us ON us.DisplayName = user_rank.DisplayName
LEFT JOIN 
    PostActivity pa ON pa.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.Tags LIKE '%' || ts.TagName || '%'
    )
ORDER BY 
    ts.PostCount DESC, us.PostsCreated DESC;
