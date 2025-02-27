WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        AVG(p.ViewCount) AS AvgPostViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT t.TagName) AS UniqueTagCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT DISTINCT unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName FROM Posts) t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation, 
        AvgPostViews,
        QuestionCount,
        AnswerCount,
        BadgeCount,
        UniqueTagCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, AvgPostViews DESC, BadgeCount DESC) AS Rank
    FROM 
        UserStats
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        QuestionCount,
        AnswerCount,
        BadgeCount,
        UniqueTagCount
    FROM 
        RankedUsers
    WHERE 
        Rank <= 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3), 0) AS Downvotes,
        SUM(CASE 
                WHEN ph.PostHistoryTypeId = 10 THEN 1 
                ELSE 0 
            END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    pd.Title,
    pd.Upvotes,
    pd.Downvotes,
    pd.CloseCount,
    CASE 
        WHEN pd.CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN pd.Upvotes - pd.Downvotes > 0 THEN 'Positive' 
        WHEN pd.Upvotes - pd.Downvotes < 0 THEN 'Negative' 
        ELSE 'Neutral' 
    END AS Sentiment
FROM 
    TopUsers tu
JOIN 
    PostDetails pd ON tu.UserId = pd.OwnerUserId
ORDER BY 
    tu.Reputation DESC, pd.Upvotes DESC 
LIMIT 100;
