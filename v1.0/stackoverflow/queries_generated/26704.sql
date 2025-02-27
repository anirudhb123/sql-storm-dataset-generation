WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            WHEN p.PostTypeId = 4 THEN 'TagWikiExcerpt'
            ELSE 'Other'
        END AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FilteredQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Body,
        ur.DisplayName,
        ur.Reputation,
        ur.PostCount,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges
    FROM 
        RankedPosts rp
    INNER JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.PostType = 'Question' 
        AND (LOWER(rp.Body) LIKE '%performance%' OR LOWER(rp.Body) LIKE '%benchmark%')
)
SELECT 
    fq.PostId,
    fq.Title,
    fq.Tags,
    fq.Body,
    fq.DisplayName AS AuthorName,
    fq.Reputation AS AuthorReputation,
    fq.PostCount AS TotalPosts,
    fq.GoldBadges AS GoldBadgeCount,
    fq.SilverBadges AS SilverBadgeCount,
    fq.BronzeBadges AS BronzeBadgeCount
FROM 
    FilteredQuestions fq
ORDER BY 
    fq.Reputation DESC,
    fq.PostId;
