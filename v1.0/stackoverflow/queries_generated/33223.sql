WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS UserName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
RecentPostUpdates AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserDisplayName
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '30 days')
        AND ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Body, Tags
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(c.CommentCount + pvs.UpVotes - pvs.DownVotes, 0) AS EngagementScore
    FROM 
        Posts p
        LEFT JOIN PostVoteSummary pvs ON p.Id = pvs.PostId
        LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.UserName,
    COUNT(DISTINCT pt.TagName) AS UniqueTags,
    e.EngagementScore,
    COALESCE(ptg.TagCount, 0) AS PopularTagCount
FROM 
    RankedPosts rp
    LEFT JOIN PostEngagement e ON rp.PostId = e.PostId
    LEFT JOIN PopularTags ptg ON e.PostId = ANY(SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || ptg.TagName || '%')
WHERE 
    rp.Rank <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.UserName, e.EngagementScore, ptg.TagCount
ORDER BY 
    e.EngagementScore DESC, rp.Score DESC;
