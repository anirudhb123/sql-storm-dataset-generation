
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate,
        @row_number := IF(@prev_tag = p.Tags, @row_number + 1, 1) AS TagRank,
        @prev_tag := p.Tags,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_tag := '') AS init
    GROUP BY
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.LastActivityDate, p.Tags
),
TopQuestions AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.TagRank,
        rp.VoteCount,
        rp.UpVotes,
        rp.DownVotes
    FROM
        RankedPosts rp
    WHERE
        rp.TagRank = 1
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        CASE
            WHEN u.Reputation IS NULL THEN 'Anonymous'
            WHEN u.Reputation < 100 THEN 'Newbie'
            WHEN u.Reputation < 1000 THEN 'Regular'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM
        Users u
)
SELECT
    tq.PostId,
    tq.Title,
    ur.Reputation,
    ur.ReputationLevel,
    tq.UpVotes,
    tq.DownVotes,
    CASE
        WHEN COALESCE(tq.UpVotes, 0) = 0 THEN 'No Upvotes'
        WHEN COALESCE(tq.DownVotes, 0) = 0 THEN 'No Downvotes'
        ELSE 'Mixed Votes'
    END AS VoteStatus,
    MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastCloseDate,
    GROUP_CONCAT(DISTINCT pht.Name ORDER BY pht.Name SEPARATOR ', ') AS PostHistoryTypes
FROM
    TopQuestions tq
LEFT JOIN 
    Users u ON tq.OwnerUserId = u.Id
LEFT JOIN
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN
    PostHistory ph ON tq.PostId = ph.PostId
LEFT JOIN
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY
    tq.PostId, tq.Title, ur.Reputation, ur.ReputationLevel, tq.UpVotes, tq.DownVotes
HAVING
    COUNT(ph.Id) > 0 OR SUM(tq.UpVotes + tq.DownVotes) > 10
ORDER BY
    tq.UpVotes DESC,
    tq.DownVotes ASC,
    tq.Title;
