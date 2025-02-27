WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > 0
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotesCount -- VoteTypeId = 2 for upvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation >= 1000 
    GROUP BY 
        u.Id
),
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.TotalScore,
        ups.UpVotesCount,
        rp.Title,
        rp.RankScore
    FROM 
        UserPostStats ups
    LEFT JOIN 
        RankedPosts rp ON ups.UserId = rp.PostId
    WHERE 
        rp.RankScore <= 5 
),
FinalStats AS (
    SELECT 
        cs.DisplayName,
        cs.PostCount,
        cs.TotalScore,
        cs.UpVotesCount,
        (cs.UpVotesCount * 1.0 / NULLIF(cs.PostCount, 0)) * 100 AS UpvotePercentage, 
        COALESCE(tag.TagName, 'No Tags') AS PopularTag
    FROM 
        CombinedStats cs
    LEFT JOIN 
        (SELECT 
             unnest(string_to_array(p.Tags, '><')) AS TagName, 
             PostId 
         FROM 
             Posts p 
         WHERE 
             p.Tags IS NOT NULL) AS tag ON cs.PostId = tag.PostId
)
SELECT 
    fs.DisplayName,
    fs.PostCount,
    fs.TotalScore,
    fs.UpVotesCount,
    fs.UpvotePercentage,
    fs.PopularTag
FROM 
    FinalStats fs
WHERE 
    fs.UpvotePercentage > 50
ORDER BY 
    fs.TotalScore DESC, 
    fs.UpVotesCount DESC;
