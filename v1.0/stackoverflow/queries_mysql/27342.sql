
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Body,
        p.Tags,
        p.OwnerUserId,
        LENGTH(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', -1), '><', 1)) + 1 AS TagCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.AcceptedAnswerId IS NOT NULL  
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.PostId) AS VotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        LOWER(TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', -1), '><', 1))) AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.TagCount,
    ue.UserId,
    ue.DisplayName,
    ue.VotesReceived,
    ue.UpVotes,
    ue.DownVotes,
    pt.Tag AS PopularTag,
    pt.UsageCount
FROM 
    RankedPosts rp
JOIN 
    UserEngagement ue ON rp.OwnerUserId = ue.UserId
LEFT JOIN 
    PopularTags pt ON FIND_IN_SET(pt.Tag, SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', -1), '><', 1)) > 0
WHERE 
    rp.Rank <= 50  
ORDER BY 
    rp.Rank;
