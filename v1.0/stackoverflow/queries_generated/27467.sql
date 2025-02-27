WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY STRING_AGG(tag.TagName, ',') ORDER BY p.Score DESC) AS TagRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN 
        LATERAL STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><') AS tags
    LEFT JOIN 
        Tags tag ON tag.TagName = tags
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Questions Only
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.AvgReputation,
        rp.CreationDate,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS PostRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank = 1 -- Top Ranked Posts per Tag
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.CommentCount,
    fp.UpvoteCount,
    fp.AvgReputation,
    fp.CreationDate
FROM 
    FilteredPosts fp
WHERE 
    fp.PostRank <= 10 -- Taking top 10 posts
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
