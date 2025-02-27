
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.Tags, 
        u.Reputation,
        @row_number := IF(@post_type_id = p.PostTypeId, @row_number + 1, 1) AS Rank,
        COALESCE(p.ViewCount, 0) AS ViewCountAdjusted,
        p.OwnerUserId,
        @post_type_id := p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0, @post_type_id := NULL) r
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
        AND p.Score IS NOT NULL
    ORDER BY 
        p.PostTypeId, p.Score DESC
), 
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5 
), 
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 6) THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCountAdjusted,
    ut.DisplayName,
    ut.BadgeCount,
    pt.Tag,
    pt.TagCount,
    CASE 
        WHEN ut.UpVotesCount IS NULL THEN 'No Votes'
        ELSE 'Votes Counted'
    END AS VotesStatus,
    COALESCE(rp.Rank, 0) AS PostRank,
    CASE
        WHEN rp.ViewCountAdjusted > 1000 THEN 'Highly Viewed'
        ELSE 'Less Viewed'
    END AS ViewCategory,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = rp.OwnerUserId AND p.PostTypeId = 2) AS AnswersCount
FROM 
    RankedPosts rp
JOIN 
    UserStatistics ut ON rp.OwnerUserId = ut.UserId
LEFT JOIN 
    PopularTags pt ON pt.Tag = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, ',', numbers.n), ',', -1))
WHERE 
    rp.Rank <= 5
    AND (ut.UpVotesCount > ut.DownVotesCount OR ut.BadgeCount >= 1)
ORDER BY 
    rp.Score DESC, 
    ut.BadgeCount DESC;
