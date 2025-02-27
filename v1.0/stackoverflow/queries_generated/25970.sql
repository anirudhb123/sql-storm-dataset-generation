WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY ARRAY(SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))) ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
),
PopularPosts AS (
    SELECT 
        rp.*,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId
    LEFT JOIN 
        Badges b ON b.UserId = rp.OwnerUserId
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.LastActivityDate, rp.ViewCount, rp.Score, rp.Tags, rp.Rank
),
FinalSelection AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Body,
        pp.CreationDate,
        pp.LastActivityDate,
        pp.ViewCount,
        pp.Score,
        pp.Tags,
        pp.CommentCount,
        pp.VoteCount,
        pp.TotalBadges,
        RANK() OVER (ORDER BY pp.Score DESC, pp.CommentCount DESC, pp.ViewCount DESC) AS FinalRank
    FROM 
        PopularPosts pp
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.Body,
    fs.CreationDate,
    fs.LastActivityDate,
    fs.ViewCount,
    fs.Score,
    fs.Tags,
    fs.CommentCount,
    fs.VoteCount,
    fs.TotalBadges
FROM 
    FinalSelection fs
WHERE 
    fs.FinalRank <= 10  -- Top 10 posts based on score, comments and views
ORDER BY 
    fs.FinalRank;
