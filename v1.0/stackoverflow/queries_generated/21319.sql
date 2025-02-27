WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COALESCE(CONVERT(int, SUBSTRING(p.Body, PATINDEX('%<p>%', p.Body), LEN(p.Body))), 0), 0) AS NonEmptyBodyLength
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate BETWEEN DATEADD(month, -6, GETDATE()) AND GETDATE() 
        AND p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
FilteredPosts AS (
    SELECT 
        rp.*, 
        ur.Reputation, 
        ur.BadgeCount,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        CASE 
            WHEN UpVotes = 0 AND DownVotes = 0 THEN 'No votes'
            WHEN (UpVotes - DownVotes) > 0 THEN 'Positive votes'
            WHEN (UpVotes - DownVotes) < 0 THEN 'Negative votes'
            ELSE 'Neutral votes'
        END AS VoteStatus
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        ur.Reputation IS NOT NULL
),
FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Reputation,
        fp.BadgeCount,
        fp.GoldBadges,
        fp.SilverBadges,
        fp.BronzeBadges,
        fp.VoteStatus,
        ROW_NUMBER() OVER (ORDER BY fp.CreationDate DESC, fp.NonEmptyBodyLength DESC) AS RowNum
    FROM 
        FilteredPosts fp
    WHERE 
        fp.PostRank = 1 
        AND (fp.NonEmptyBodyLength > 100 OR fp.VoteStatus IN ('Positive votes', 'Neutral votes'))
)
SELECT 
    fr.*,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = fr.PostId) AS CommentCount,
    (SELECT string_agg(T.TagName, ', ') 
     FROM Tags T 
     JOIN LATERAL string_to_array(fr.Tags, '><') AS tags ON tags.value = T.TagName 
     WHERE T.Id IS NOT NULL) AS RelatedTags
FROM 
    FinalResults fr
WHERE 
    fr.Reputation >= 100
    AND fr.VoteStatus <> 'Negative votes'
ORDER BY 
    fr.CommentCount DESC, fr.CreationDate DESC;
