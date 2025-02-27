WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS t ON p.Id = t.Id
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.PostTypeId
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(c.Id) AS CommentCount,
        SUM(vote.VoteTypeId = 2) AS UpVotes,
        SUM(vote.VoteTypeId = 3) AS DownVotes,
        AVG(COALESCE(vote.BountyAmount, 0)) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes vote ON u.Id = vote.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS EditCount, 
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.Score,
    p.Tags,
    ua.UserId,
    ua.DisplayName,
    ua.CommentCount,
    COALESCE(NULLIF(ua.UpVotes, 0), 1/NULLIF(ua.DownVotes, 0)) AS VoteRatio,
    phd.EditCount,
    phd.LastEditDate,
    phd.HistoryTypes
FROM 
    RankedPosts p
LEFT JOIN 
    UserActivity ua ON p.PostId IN (SELECT ParentId FROM Posts WHERE PostTypeId = 2) -- Answers corresponding to the PostId
LEFT JOIN 
    PostHistoryDetails phd ON p.PostId = phd.PostId
WHERE 
    p.RankByScore <= 5                                     -- Top 5 posts per type
    AND (p.CreationDate >= NOW() - INTERVAL '30 days')  -- Posts created within the last 30 days
    AND (phd.EditCount > 1 OR phd.EditCount IS NULL)     -- Only include posts that have been edited more than once or are not edited
ORDER BY 
    p.Score DESC, ua.CommentCount DESC;
