WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum,
        p.OwnerUserId,
        CASE 
            WHEN CHAR_LENGTH(p.Body) - CHAR_LENGTH(REPLACE(p.Body, '<', '')) > 0 
            THEN 'Contains HTML'
            ELSE 'Plain Text'
        END AS BodyType,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM Posts as child 
                WHERE child.ParentId = p.Id
            ) THEN 'Has Answers'
            ELSE 'No Answers'
        END AS AnswerStatus
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1  -- Only questions
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId, p.Body
),
PopularPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.ViewCount,
        ps.Score,
        ps.UpVotes,
        ps.DownVotes,
        ps.BodyType,
        ps.AnswerStatus,
        (ps.UpVotes - ps.DownVotes) AS VoteBalance,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS PopularityRank
    FROM PostStats ps
    WHERE ps.ViewCount > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
FinalResult AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ur.UserId,
        ur.Reputation,
        ur.BadgeCount,
        p.VoteBalance,
        p.BodyType,
        p.AnswerStatus,
        p.PopularityRank,
        CASE 
            WHEN ur.Reputation > 100 THEN 'Expert'
            WHEN ur.Reputation BETWEEN 50 AND 100 THEN 'Intermediate'
            ELSE 'Novice'
        END AS UserExpertise
    FROM PopularPosts p
    LEFT JOIN UserReputation ur ON p.OwnerUserId = ur.UserId
)
SELECT 
    *,
    CASE 
        WHEN UserExpertise IS NULL THEN 'No Reputation'
        ELSE UserExpertise
    END AS UserExpertiseStatus,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = fr.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = fr.PostId AND ph.PostHistoryTypeId = 10) AS CloseCount
FROM FinalResult fr
WHERE PopularityRank < 101  -- Top 100 popular posts
ORDER BY fr.Score DESC, fr.ViewCount DESC;
