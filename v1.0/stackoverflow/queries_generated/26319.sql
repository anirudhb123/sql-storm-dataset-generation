WITH UserScoreStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS NetScore,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation > 1000 -- Filtering users with significant reputation
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes
),
TopPostTypes AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
    ORDER BY 
        PostCount DESC
    LIMIT 5 -- Getting top 5 post types
),
RecentPostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        P.ViewCount,
        P.Score,
        RANK() OVER (PARTITION BY DATE(P.CreationDate) ORDER BY P.LastActivityDate DESC) AS RankByActivity
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days' -- Recent posts only
    GROUP BY 
        P.Id, U.DisplayName
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS TagName ON TRUE
    JOIN 
        Tags T ON T.TagName = TagName
    GROUP BY 
        P.Id
)
SELECT 
    USS.UserId,
    USS.DisplayName,
    USS.Reputation,
    USS.NetScore,
    USS.PostCount,
    USS.CommentCount,
    TPT.PostType,
    RPA.PostId,
    RPA.Title,
    RPA.CreationDate,
    RPA.LastActivityDate,
    RPA.CommentCount AS RecentCommentCount,
    RPA.ViewCount,
    RPA.Score,
    PT.Tags
FROM 
    UserScoreStats USS
JOIN 
    TopPostTypes TPT ON USS.PostCount > 0 -- Only consider users who made posts
JOIN 
    RecentPostActivity RPA ON USS.UserId = RPA.OwnerDisplayName
JOIN 
    PostTags PT ON PT.PostId = RPA.PostId
WHERE 
    RPA.RankByActivity <= 3 -- Filtering for top 3 active recent posts
ORDER BY 
    USS.NetScore DESC, RPA.LastActivityDate DESC;
