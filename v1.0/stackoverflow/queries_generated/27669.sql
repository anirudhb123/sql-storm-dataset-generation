WITH RankedTags AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewCountPosts,
        SUM(CASE WHEN Posts.AnswerCount > 0 THEN 1 ELSE 0 END) AS ActivePosts,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT Posts.Id) DESC) AS Rank
    FROM 
        Posts
    INNER JOIN 
        UNNEST(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')) AS Tags(TagName)
    WHERE 
        Posts.PostTypeId = 1 -- Consider only Questions
    GROUP BY 
        Tags.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        HighViewCountPosts,
        ActivePosts
    FROM 
        RankedTags
    WHERE 
        Rank <= 10 -- Top 10 tags
),
UserStats AS (
    SELECT 
        Users.DisplayName,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostedQuestions,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.DisplayName, Users.Reputation
),
UserEngagement AS (
    SELECT 
        UserStats.DisplayName,
        UserStats.Reputation,
        UserStats.PostedQuestions,
        UserStats.UpVotesReceived,
        UserStats.DownVotesReceived,
        COALESCE(TotalBadges.BadgeCount, 0) AS BadgeCount
    FROM 
        UserStats
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) AS TotalBadges ON UserStats.DisplayName = TotalBadges.UserId
)
SELECT 
    T.TagName,
    T.PostCount AS QuestionsPosted,
    T.HighViewCountPosts AS PopularQuestions,
    T.ActivePosts AS AnsweredQuestions,
    U.DisplayName AS UserOwner,
    U.Reputation,
    U.PostedQuestions,
    U.UpVotesReceived,
    U.DownVotesReceived,
    U.BadgeCount
FROM 
    TopTags T
JOIN 
    Posts P ON P.Tags LIKE '%' || T.TagName || '%'
JOIN 
    Users U ON P.OwnerUserId = U.Id
ORDER BY 
    T.PostCount DESC, U.Reputation DESC;
