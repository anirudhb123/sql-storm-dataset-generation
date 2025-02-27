WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByOwner
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
), 
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(Tags, '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT bh.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    GROUP BY 
        u.Id
), 
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS FirstClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    gs.TotalUpVotes,
    gs.TotalDownVotes,
    gs.TotalBadges,
    pt.FirstClosedDate,
    pt.CloseCount,
    array_agg(pt.TagName) AS TopTags
FROM 
    RankedPosts rp
JOIN 
    UserStats gs ON rp.OwnerDisplayName = gs.DisplayName
LEFT JOIN 
    PostHistorySummary pt ON rp.PostId = pt.PostId
JOIN 
    PopularTags t ON t.TagName = ANY(STRING_TO_ARRAY(rp.Tags, '>'))
WHERE 
    rp.RankByOwner <= 5
GROUP BY 
    rp.PostId, gs.UserId, pt.FirstClosedDate, pt.CloseCount
ORDER BY 
    rp.CreationDate DESC;
