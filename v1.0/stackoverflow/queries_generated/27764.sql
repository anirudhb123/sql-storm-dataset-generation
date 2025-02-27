WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        ph.UserId AS LastEditorId,
        ph.UserDisplayName AS LastEditorName,
        ph.CreationDate AS LastEditDate,
        COALESCE(p.ClosedDate, 'No Closure') AS ClosureStatus,
        ARRAY_AGG(DISTINCT tag.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) as tag(TagName) 
    GROUP BY 
        p.Id, u.DisplayName, ph.UserId, ph.UserDisplayName
),
EngagementRanking AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.Reputation,
        ue.PostCount,
        ue.CommentCount,
        ue.UpVotes,
        ue.DownVotes,
        ue.GoldBadges,
        ue.SilverBadges,
        ue.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY ue.Reputation DESC, ue.PostCount DESC) AS EngagementRank
    FROM 
        UserEngagement ue
)
SELECT 
    er.EngagementRank,
    er.DisplayName,
    er.Reputation,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ClosureStatus,
    pd.LastEditorName,
    pd.LastEditDate,
    pd.TagsArray
FROM 
    EngagementRanking er
JOIN 
    PostDetails pd ON er.UserId = pd.LastEditorId
WHERE 
    er.EngagementRank <= 10
ORDER BY 
    er.EngagementRank, pd.CreationDate DESC;
