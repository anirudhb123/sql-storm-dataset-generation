WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COALESCE(SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TagFrequency AS (
    SELECT 
        unnest(string_to_array(p.Tags, '>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS rn
    FROM 
        TagFrequency
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    RANK() OVER (ORDER BY up.Reputation DESC) AS ReputationRank,
    rp.PostId,
    rp.Title,
    COALESCE(tf.TagCount, 0) AS MostFrequentTagCount,
    COUNT(DISTINCT cm.Id) AS CommentCount,
    COALESCE(us.UpVotesCount, 0) AS TotalUpVotes,
    COALESCE(us.DownVotesCount, 0) AS TotalDownVotes,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    CASE 
        WHEN us.Reputation < 1000 THEN 'Newbie'
        WHEN us.Reputation BETWEEN 1000 AND 5000 THEN 'Expert'
        ELSE 'Veteran'
    END AS UserCategory
FROM 
    Users up
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN 
    Comments cm ON rp.PostId = cm.PostId
LEFT JOIN 
    UserStats us ON up.Id = us.UserId
LEFT JOIN 
    (SELECT TagName 
     FROM TopTags 
     WHERE rn = 1) AS tf ON tf.TagName IN (SELECT unnest(string_to_array(rp.Tags, '>')))
WHERE 
    rp.rn = 1 -- Only latest post of user
GROUP BY 
    up.UserId, up.DisplayName, up.Reputation, rp.PostId, rp.Title, tf.TagCount
ORDER BY 
    ReputationRank;
