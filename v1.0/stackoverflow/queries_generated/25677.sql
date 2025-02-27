WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(Id) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            UNNEST(string_to_array(Tags, ',')) AS TagName
        FROM 
            Posts) t ON p.Id = t.PostId
    GROUP BY 
        p.Id, u.DisplayName, v.UpVotes, v.DownVotes, c.CommentCount
),
UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgPostLifetime
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ui.PostCount,
    ui.TotalUpVotes AS UserTotalUpVotes,
    ui.TotalDownVotes AS UserTotalDownVotes,
    ROUND(ui.AvgPostLifetime / 86400, 2) AS AvgPostLifetimeInDays,
    pd.Title,
    pd.TotalUpVotes,
    pd.TotalDownVotes,
    pd.CommentCount,
    pd.TagsArray
FROM 
    UserBadges ub
LEFT JOIN 
    UserInteractions ui ON ub.UserId = ui.UserId
LEFT JOIN 
    (SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(Id) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            UNNEST(string_to_array(Tags, ',')) AS TagName
        FROM 
            Posts) t ON
