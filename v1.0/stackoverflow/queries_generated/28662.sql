WITH TagAggregates AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (10, 11, 12, 19) THEN 1 ELSE 0 END) AS ClosedPostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    GROUP BY 
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        pt.Name AS PostType,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    ta.TagName,
    ta.PostCount,
    ta.QuestionCount,
    ta.AnswerCount,
    ta.ClosedPostCount,
    ur.DisplayName AS TopContributor,
    ur.Reputation AS ContributorReputation,
    ur.GoldBadgeCount,
    ur.SilverBadgeCount,
    ur.BronzeBadgeCount,
    pd.Title AS RecentPostTitle,
    pd.CreationDate AS PostCreationDate,
    pd.OwnerDisplayName
FROM 
    TagAggregates ta
LEFT JOIN 
    UserReputation ur ON ur.Reputation = (
        SELECT MAX(Reputation) 
        FROM UserReputation 
        WHERE BadgeCount > 0
    )
LEFT JOIN 
    PostDetails pd ON pd.PostId = (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.Tags LIKE '%' || ta.TagName || '%'
        ORDER BY p.CreationDate DESC
        LIMIT 1
    )
ORDER BY 
    ta.PostCount DESC, ta.TagName;
