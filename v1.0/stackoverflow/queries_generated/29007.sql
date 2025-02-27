WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        STRING_AGG(t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p 
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int[])
    WHERE 
        p.PostTypeId = 1 -- Filtering for questions
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
),

VoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),

BadgeDetails AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.Score,
    pd.Tags,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(vs.TotalVotes, 0) AS TotalVotes,
    COALESCE(bd.GoldBadges, 0) AS GoldBadges,
    COALESCE(bd.SilverBadges, 0) AS SilverBadges,
    COALESCE(bd.BronzeBadges, 0) AS BronzeBadges
FROM 
    PostDetails pd
LEFT JOIN 
    VoteStats vs ON pd.PostId = vs.PostId
LEFT JOIN 
    BadgeDetails bd ON pd.OwnerDisplayName = bd.UserId
ORDER BY 
    pd.CreationDate DESC
LIMIT 100;
