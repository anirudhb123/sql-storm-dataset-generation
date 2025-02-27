WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)) / 3600) AS AvgHoursToActivity
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views, u.UpVotes, u.DownVotes
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        UpVotes,
        DownVotes,
        TotalPosts,
        Questions,
        Answers,
        AvgHoursToActivity,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
),
ActivePostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, p.CreationDate, p.LastActivityDate
),
TopActivePosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        CreationDate,
        LastActivityDate,
        VoteCount,
        Tags,
        ROW_NUMBER() OVER (ORDER BY ViewCount DESC) AS Rank
    FROM 
        ActivePostStatistics
),
SelectedData AS (
    SELECT 
        tu.DisplayName,
        tu.Reputation,
        tu.TotalPosts,
        tu.AvgHoursToActivity,
        tap.Title AS MostViewedPostTitle,
        tap.ViewCount AS MostViewedPostCount,
        tap.Tags AS AssociatedTags
    FROM 
        TopUsers tu
    JOIN 
        TopActivePosts tap ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tap.PostId)
    WHERE 
        tu.Rank <= 10 AND tap.Rank = 1
)
SELECT 
    DisplayName,
    Reputation,
    TotalPosts,
    AvgHoursToActivity,
    MostViewedPostTitle,
    MostViewedPostCount,
    AssociatedTags
FROM 
    SelectedData;
